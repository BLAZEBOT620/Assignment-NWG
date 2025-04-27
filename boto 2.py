import boto3

def list_s3_buckets():
    # Create an S3 client
    s3 = boto3.client('s3')

    # List all buckets
    response = s3.list_buckets()
    
    # Extract bucket names from the response
    print("List of S3 Buckets:")
    for bucket in response['Buckets']:
        print(bucket['Name'])

def count_objects_in_bucket(bucket_name):
    # Create an S3 client
    s3 = boto3.client('s3')
    
    # Get the list of objects in the specified bucket
    response = s3.list_objects_v2(Bucket=bucket_name)
    
    # Check if the bucket contains objects
    if 'Contents' in response:
        total_objects = len(response['Contents'])
        print(f"Total number of objects in the bucket '{bucket_name}': {total_objects}")
    else:
        print(f"No objects found in the bucket '{bucket_name}'.")

def main():
    # List all S3 buckets
    list_s3_buckets()
    
    # Ask the user for a bucket name
    bucket_name = input("Enter the name of the S3 bucket to count objects: ")
    
    # Count the objects in the specified bucket
    count_objects_in_bucket(bucket_name)

if __name__ == "__main__":
    main()
