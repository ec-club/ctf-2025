import os
import boto3
from fastapi import APIRouter

client = boto3.client("kms")

key_id = os.getenv("KMS_KEY_ID")
if not key_id:
    raise ValueError("KMS_KEY_ID environment variable not set")

router = APIRouter()


@router.get("/meta/region")
def get_region():
    return client.meta.region_name


@router.get("/meta/key-id")
def get_key_id():
    return key_id
