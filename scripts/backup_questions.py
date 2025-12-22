#!/usr/bin/env python3

import sys
import os
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore

def main():
    print('🔄 Starting questions archive process...')
    
    try:
        # Initialize Firebase
        if not firebase_admin._apps:
            # Try to load credentials from cred.json first
            cred_file = 'cred.json'
            if os.path.exists(cred_file):
                cred = credentials.Certificate(cred_file)
                firebase_admin.initialize_app(cred)
                print(f'✅ Loaded credentials from {cred_file}')
            else:
                # Fallback to other credential methods
                try:
                    cred = credentials.ApplicationDefault()
                    firebase_admin.initialize_app(cred)
                    print('✅ Using application default credentials')
                except:
                    # Try environment variable
                    service_account_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
                    if service_account_path and os.path.exists(service_account_path):
                        cred = credentials.Certificate(service_account_path)
                        firebase_admin.initialize_app(cred)
                        print(f'✅ Loaded credentials from {service_account_path}')
                    else:
                        print('❌ Firebase credentials not found.')
                        print('   Options:')
                        print('   1. Place service account key as "cred.json" in project root')
                        print('   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable')
                        print('   3. Run: gcloud auth application-default login')
                        sys.exit(1)
        
        db = firestore.client()
        print('✅ Firebase initialized successfully')
        
        # Generate date string for archive path (YYYY-MM-DD)
        now = datetime.now()
        date_string = now.strftime('%Y-%m-%d')
        
        print(f'📅 Archive date: {date_string}')
        
        # Get all questions from the main collection
        print('📖 Reading questions from main collection...')
        questions_ref = db.collection('questions')
        questions_docs = questions_ref.stream()
        
        # Convert to list to get count and process
        questions_list = list(questions_docs)
        total_questions = len(questions_list)
        
        print(f'📊 Found {total_questions} questions to archive')
        
        if total_questions == 0:
            print('⚠️  No questions found to archive')
            return
        
        # Process questions in batches
        batch_size = 500  # Firestore batch limit
        processed_count = 0
        
        # Process in batches
        for i in range(0, total_questions, batch_size):
            batch = db.batch()
            batch_end = min(i + batch_size, total_questions)
            
            for j in range(i, batch_end):
                question_doc = questions_list[j]
                question_id = question_doc.id
                question_data = question_doc.to_dict()
                
                # Add to archive collection: archive/questions/{date}/{questionId}
                archive_doc_ref = (db.collection('archive')
                                 .document('questions')
                                 .collection(date_string)
                                 .document(question_id))
                
                batch.set(archive_doc_ref, question_data)
                processed_count += 1
                
                # Show progress every 100 questions
                if processed_count % 100 == 0:
                    print(f'📝 Processed {processed_count}/{total_questions} questions...')
            
            # Commit the batch
            batch.commit()
            batch_num = (i // batch_size) + 1
            total_batches = (total_questions + batch_size - 1) // batch_size
            print(f'✅ Committed batch {batch_num}/{total_batches}')
        
        print('')
        print('🎉 Archive completed successfully!')
        print('📊 Summary:')
        print(f'   • Total questions archived: {total_questions}')
        print(f'   • Batches executed: {(total_questions + batch_size - 1) // batch_size}')
        print(f'   • Archive location: archive/questions/{date_string}/')
        print(f'   • Archive date: {date_string}')
        
    except Exception as e:
        print('❌ Error during archive process:')
        print(f'Error: {e}')
        import traceback
        print(f'Stack trace: {traceback.format_exc()}')
        sys.exit(1)

if __name__ == '__main__':
    main()