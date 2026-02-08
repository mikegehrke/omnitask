"""
Migration: Add file fields to messages table
Adds: file_url, file_name, file_type columns
Makes content nullable (for file-only messages)
"""
import asyncio
from sqlalchemy import text
from app.db.base import engine


async def migrate():
    """Add file fields to messages table"""
    async with engine.begin() as conn:
        # Check if columns already exist
        result = await conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'messages' 
            AND column_name IN ('file_url', 'file_name', 'file_type')
        """))
        existing_columns = {row[0] for row in result.fetchall()}
        
        # Add file_url if not exists
        if 'file_url' not in existing_columns:
            await conn.execute(text("""
                ALTER TABLE messages 
                ADD COLUMN file_url VARCHAR
            """))
            print("✅ Added column: file_url")
        else:
            print("ℹ️  Column file_url already exists")
        
        # Add file_name if not exists
        if 'file_name' not in existing_columns:
            await conn.execute(text("""
                ALTER TABLE messages 
                ADD COLUMN file_name VARCHAR
            """))
            print("✅ Added column: file_name")
        else:
            print("ℹ️  Column file_name already exists")
        
        # Add file_type if not exists
        if 'file_type' not in existing_columns:
            await conn.execute(text("""
                ALTER TABLE messages 
                ADD COLUMN file_type VARCHAR
            """))
            print("✅ Added column: file_type")
        else:
            print("ℹ️  Column file_type already exists")
        
        # Make content nullable (for file-only messages)
        await conn.execute(text("""
            ALTER TABLE messages 
            ALTER COLUMN content DROP NOT NULL
        """))
        print("✅ Made content column nullable")
        
        print("\n✅ Migration completed successfully")


async def rollback():
    """Rollback migration (remove file fields)"""
    async with engine.begin() as conn:
        await conn.execute(text("""
            ALTER TABLE messages 
            DROP COLUMN IF EXISTS file_url,
            DROP COLUMN IF EXISTS file_name,
            DROP COLUMN IF EXISTS file_type
        """))
        
        await conn.execute(text("""
            ALTER TABLE messages 
            ALTER COLUMN content SET NOT NULL
        """))
        
        print("✅ Migration rolled back successfully")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "rollback":
        asyncio.run(rollback())
    else:
        asyncio.run(migrate())
