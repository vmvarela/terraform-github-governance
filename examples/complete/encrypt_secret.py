#!/usr/bin/env python3
"""
Script to encrypt secrets for GitHub Actions using the organization's public key.
Usage: python3 encrypt_secret.py "your-secret-value"
"""
import sys
import base64
from nacl import encoding, public

# Organization public key (base64 encoded)
PUBLIC_KEY = "FCgAbrpmBl+K8b8vT+XLaytWQaO8KQHHNG/ABS+tKQU="

def encrypt_secret(secret_value: str) -> str:
    """Encrypt a secret using the organization's public key."""
    # Decode the public key
    public_key = public.PublicKey(PUBLIC_KEY.encode("utf-8"), encoding.Base64Encoder())
    
    # Create a sealed box
    sealed_box = public.SealedBox(public_key)
    
    # Encrypt the secret
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    
    # Encode to base64
    return base64.b64encode(encrypted).decode("utf-8")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 encrypt_secret.py 'your-secret-value'")
        sys.exit(1)
    
    secret_value = sys.argv[1]
    encrypted_value = encrypt_secret(secret_value)
    
    print(f"Encrypted value (copy this to terraform.tfvars):")
    print(encrypted_value)
