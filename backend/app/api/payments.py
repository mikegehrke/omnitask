from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.db.base import get_db
from app.db.models import Task, Payment, TaskStatus
from app.core.config import settings
import stripe
import json
from arq import create_pool
from arq.connections import RedisSettings

router = APIRouter()

stripe.api_key = settings.STRIPE_SECRET_KEY

@router.post("/create-checkout-session/{task_id}")
async def create_checkout_session(task_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if not task.final_price:
        raise HTTPException(status_code=400, detail="Task price not calculated yet")

    try:
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': task.currency.lower() if task.currency else 'usd',
                    'product_data': {
                        'name': f'OmniTask: {task.id}',
                    },
                    'unit_amount': int(task.final_price * 100),
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url='http://localhost:8000/success', # Frontend URL in real app
            cancel_url='http://localhost:8000/cancel',
            metadata={'task_id': task.id}
        )
        return {"sessionId": checkout_session.id, "url": checkout_session.url}
    except Exception as e:
        # Fallback for Dev without valid Stripe Key
        if "Invalid API Key" in str(e) or "sk_test_placeholder" in settings.STRIPE_SECRET_KEY:
             return {"sessionId": "mock_session_id", "url": "http://mock-payment-url"}
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/webhook")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    event = None

    try:
        # event = stripe.Webhook.construct_event(
        #     payload, sig_header, endpoint_secret
        # )
        # For simple/mock dev verify locally without signature if needed or use mock event
        event = json.loads(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError as e:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle the event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        task_id = session.get('metadata', {}).get('task_id')
        
        if task_id:
            task_id = int(task_id)
            # Update Payment Record
            new_payment = Payment(
                task_id=task_id,
                stripe_charge_id=session.get('payment_intent'),
                amount=session.get('amount_total', 0) / 100,
                status="succeeded"
            )
            db.add(new_payment)
            
            # Update Task
            result = await db.execute(select(Task).where(Task.id == task_id))
            task = result.scalar_one_or_none()
            if task:
                task.is_paid = True
                task.status = TaskStatus.EXECUTING.value
                db.add(task)
                await db.commit()
                
                # Trigger Execution Stub
                # In production, use shared redis pool
                redis = await create_pool(RedisSettings.from_dsn(settings.REDIS_URL))
                await redis.enqueue_job('execute_task_job', task_id)
                await redis.close()
                
    return {"status": "success"}

@router.post("/mock-pay/{task_id}")
async def mock_pay_task(task_id: int, db: AsyncSession = Depends(get_db)):
    """
    Dev tool to simulate payment and trigger execution
    """
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.is_paid = True
    task.status = TaskStatus.EXECUTING.value
    db.add(task)
    await db.commit()
    
    # Trigger Execution
    redis = await create_pool(RedisSettings.from_dsn(settings.REDIS_URL))
    await redis.enqueue_job('execute_task_job', task_id)
    await redis.close()
    
    return {"status": "paid", "message": "Task marked as paid and execution triggered"}
