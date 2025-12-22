#!/usr/bin/env python3

import sys
import os
import random
import time
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore import FieldFilter

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        app = firebase_admin.get_app()
        print("✅ Using existing Firebase app")
    except ValueError:
        cred_path = os.path.join(os.path.dirname(__file__), '..', 'cred.json')
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            app = firebase_admin.initialize_app(cred)
            print("✅ Initialized Firebase with service account")
        else:
            app = firebase_admin.initialize_app()
            print("✅ Initialized Firebase with default credentials")
    
    return firestore.client()

def migrate_questions_complete(db: firestore.Client) -> None:
    """
    Complete migration: adds sequence numbers, random seeds, timestamps, and creates metadata
    """
    print("📊 Loading existing questions...")
    
    # Load all questions - since createdAt doesn't exist yet, we'll use document ID ordering
    # This provides consistent ordering across runs
    questions_ref = db.collection('questions')
    questions_query = questions_ref.order_by('__name__')
    
    questions_docs = list(questions_query.stream())
    total_questions = len(questions_docs)
    
    print(f"📝 Found {total_questions} questions to migrate")
    
    if total_questions == 0:
        print("ℹ️ No questions found, nothing to migrate")
        return
    
    # Process in batches of 500
    batch_size = 500
    current_sequence = 1
    processed_count = 0
    max_sequence = 0
    current_time = firestore.SERVER_TIMESTAMP
    
    for i in range(0, len(questions_docs), batch_size):
        batch = db.batch()
        end_index = min(i + batch_size, len(questions_docs))
        
        batch_num = (i // batch_size) + 1
        total_batches = (total_questions + batch_size - 1) // batch_size
        
        print(f"🔄 Processing batch {batch_num}/{total_batches} (questions {i + 1}-{end_index})")
        
        for j in range(i, end_index):
            doc = questions_docs[j]
            data = doc.to_dict()
            
            # Prepare update data
            update_data = {
                'sequence': current_sequence,
                'updatedAt': current_time
            }
            
            # Add createdAt if missing (assume it's a new field for all questions)
            if 'createdAt' not in data:
                update_data['createdAt'] = current_time
            
            # Add randomSeed if missing
            if 'randomSeed' not in data:
                update_data['randomSeed'] = random.random()
            
            # Track max sequence
            max_sequence = current_sequence
            current_sequence += 1
            
            # Add to batch
            batch.update(doc.reference, update_data)
            processed_count += 1
        
        # Commit batch
        batch.commit()
        print(f"✅ Batch completed. Processed {processed_count}/{total_questions} questions")
        
        # Small delay
        time.sleep(0.1)
    
    print(f"🎉 Successfully migrated {processed_count} questions with sequence numbers 1-{max_sequence}")
    
    # Create global metadata
    create_global_metadata(db, max_sequence, total_questions)
    
    # Verify migration
    verify_migration(db, total_questions, max_sequence)

def create_global_metadata(db: firestore.Client, max_sequence: int, total_questions: int) -> None:
    """Create global sequence metadata"""
    print("📊 Creating global sequence metadata...")
    
    metadata_ref = db.collection('metadata').document('questions')
    metadata_ref.set({
        'maxSequence': max_sequence,
        'totalQuestions': total_questions,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP
    })
    
    print(f"✅ Created global metadata with maxSequence: {max_sequence}")

def verify_migration(db: firestore.Client, expected_count: int, expected_max: int) -> None:
    """Verify migration success"""
    print("🔍 Verifying migration...")
    
    # Count questions with sequence field
    questions_with_sequence = db.collection('questions').where(
        filter=FieldFilter('sequence', '>', 0)
    ).count().get()
    
    migrated_count = questions_with_sequence[0][0].value
    
    if migrated_count == expected_count:
        print(f"✅ Sequence verification: {migrated_count}/{expected_count} questions")
    else:
        print(f"⚠️ Sequence warning: Only {migrated_count}/{expected_count} questions")
    
    # Count questions with randomSeed field
    questions_with_random = db.collection('questions').where(
        filter=FieldFilter('randomSeed', '>=', 0)
    ).count().get()
    
    random_count = questions_with_random[0][0].value
    
    if random_count == expected_count:
        print(f"✅ RandomSeed verification: {random_count}/{expected_count} questions")
    else:
        print(f"⚠️ RandomSeed warning: Only {random_count}/{expected_count} questions")
    
    # Check sequence range
    all_sequences_docs = list(db.collection('questions').order_by('sequence').stream())
    sequences = [doc.to_dict().get('sequence') for doc in all_sequences_docs if doc.to_dict().get('sequence')]
    
    if sequences:
        actual_min, actual_max = min(sequences), max(sequences)
        print(f"📈 Sequence range: {actual_min} - {actual_max}")
        
        if actual_max == expected_max:
            print("✅ Max sequence matches expected")
        else:
            print(f"⚠️ Max sequence mismatch: expected {expected_max}, got {actual_max}")
    
    # Check for duplicates
    unique_sequences = set(sequences)
    if len(sequences) == len(unique_sequences):
        print("✅ No duplicate sequences found")
    else:
        print(f"⚠️ Found {len(sequences) - len(unique_sequences)} duplicate sequences")
    
    # Verify metadata
    metadata_ref = db.collection('metadata').document('questions')
    metadata_doc = metadata_ref.get()
    
    if metadata_doc.exists:
        metadata = metadata_doc.to_dict()
        print(f"✅ Global metadata created:")
        print(f"   maxSequence: {metadata.get('maxSequence')}")
        print(f"   totalQuestions: {metadata.get('totalQuestions')}")
    else:
        print("⚠️ Global metadata not found")

def main():
    """Main migration function"""
    print("🚀 Starting complete question migration...")
    print("   - Adding sequence numbers")
    print("   - Adding random seeds")
    print("   - Adding timestamps (createdAt, updatedAt)")
    print("   - Creating global metadata")
    print()
    
    try:
        # Initialize Firebase
        db = initialize_firebase()
        
        # Run complete migration
        migrate_questions_complete(db)
        
        print()
        print("✅ Complete migration finished successfully!")
        print("📋 Summary:")
        print("   ✓ Sequence numbers added (1, 2, 3, ...)")
        print("   ✓ Random seeds added (0.0 - 1.0)")
        print("   ✓ Global metadata created (metadata/questions)")
        print("   ✓ Migration verified")
        
        sys.exit(0)
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        print(f"Stack trace: {traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main()