#!/usr/bin/env python3
"""
Test script to verify admin authentication and endpoints.
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://192.168.1.4:5000"
ADMIN_USERNAME = "admin"
ADMIN_EMAIL = "admin@signify.com"
ADMIN_PASSWORD = "admin123"
ADMIN_FULLNAME = "System Administrator"

def test_admin_registration():
    """Test admin user registration"""
    print("Testing admin user registration...")
    
    registration_data = {
        "username": ADMIN_USERNAME,
        "email": ADMIN_EMAIL,
        "password": ADMIN_PASSWORD,
        "fullname": ADMIN_FULLNAME,
        "age": 30,
        "dateofbirth": "1994-01-01"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/register", json=registration_data)
        print(f"Registration response: {response.status_code}")
        print(f"Response data: {response.json()}")
        
        if response.status_code == 201:
            print("✓ Admin user registered successfully")
            return True
        elif response.status_code == 400 and "already exists" in response.json().get('error', ''):
            print("✓ Admin user already exists")
            return True
        else:
            print("✗ Failed to register admin user")
            return False
            
    except Exception as e:
        print(f"✗ Error during registration: {e}")
        return False

def make_user_admin():
    """Manually update user to admin status (requires direct DB access)"""
    print("Making user admin (this requires direct database access)...")
    print("You need to run this SQL command in your database:")
    print(f"UPDATE users SET \"isAdmin\" = true WHERE username = '{ADMIN_USERNAME}';")
    input("Press Enter after running the SQL command...")

def test_admin_login():
    """Test admin user login and get JWT token"""
    print("Testing admin user login...")
    
    login_data = {
        "username": ADMIN_USERNAME,
        "password": ADMIN_PASSWORD
    }
    
    try:
        response = requests.post(f"{BASE_URL}/login", json=login_data)
        print(f"Login response: {response.status_code}")
        response_data = response.json()
        print(f"Response data: {response_data}")
        
        if response.status_code == 200:
            token = response_data.get('access_token')
            if token:
                print("✓ Admin user logged in successfully")
                print(f"JWT Token: {token[:50]}...")
                return token
            else:
                print("✗ No access token in response")
                return None
        else:
            print("✗ Failed to login admin user")
            return None
            
    except Exception as e:
        print(f"✗ Error during login: {e}")
        return None

def test_admin_endpoints(token):
    """Test admin endpoints with the JWT token"""
    print("Testing admin endpoints...")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Test 1: Get all users
    print("\n1. Testing /admin/all-users endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/admin/all-users", headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Successfully retrieved {len(data.get('users', []))} users")
            print(f"Stats: {data.get('stats', {})}")
            
            # Get a non-admin user ID for testing
            non_admin_users = [u for u in data.get('users', []) if not u.get('isAdmin', False)]
            if non_admin_users:
                test_user_id = non_admin_users[0]['id']
                
                # Test 2: Get user details
                print(f"\n2. Testing /admin/users/{test_user_id} endpoint...")
                response = requests.get(f"{BASE_URL}/admin/users/{test_user_id}", headers=headers)
                print(f"Status: {response.status_code}")
                
                if response.status_code == 200:
                    print("✓ Successfully retrieved user details")
                    user_data = response.json()
                    print(f"User: {user_data.get('user', {}).get('username', 'N/A')}")
                else:
                    print(f"✗ Failed to get user details: {response.json()}")
                
                # Test 3: Update user active status
                print(f"\n3. Testing /admin/users/{test_user_id}/active-status endpoint...")
                status_data = {"status": "inactive"}
                response = requests.put(f"{BASE_URL}/admin/users/{test_user_id}/active-status", 
                                      headers=headers, json=status_data)
                print(f"Status: {response.status_code}")
                
                if response.status_code == 200:
                    print("✓ Successfully updated user status")
                    # Revert the change
                    status_data = {"status": "active"}
                    requests.put(f"{BASE_URL}/admin/users/{test_user_id}/active-status", 
                               headers=headers, json=status_data)
                    print("✓ Reverted user status to active")
                else:
                    print(f"✗ Failed to update user status: {response.json()}")
            else:
                print("No non-admin users found for testing")
                
        else:
            print(f"✗ Failed to get all users: {response.json()}")
            
    except Exception as e:
        print(f"✗ Error during admin endpoint testing: {e}")

def main():
    """Main test function"""
    print("=== Admin Authentication Test ===\n")
    
    # Step 1: Register admin user
    if not test_admin_registration():
        print("Failed at registration step")
        return
    
    # Step 2: Make user admin (manual step)
    make_user_admin()
    
    # Step 3: Login and get token
    token = test_admin_login()
    if not token:
        print("Failed at login step")
        return
    
    # Step 4: Test admin endpoints
    test_admin_endpoints(token)
    
    print("\n=== Test Complete ===")

if __name__ == "__main__":
    main()
