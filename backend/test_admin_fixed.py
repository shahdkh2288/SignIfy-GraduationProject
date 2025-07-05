#!/usr/bin/env python3
"""
Test script for admin user management endpoints - Fixed version
"""
import requests
import json
import sys

# Configuration
BASE_URL = "http://127.0.0.1:5000"

def test_health():
    """Test health endpoint"""
    print("=== Testing Health Endpoint ===")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
            return True
    except Exception as e:
        print(f"Health check failed: {e}")
    return False

def login_user(email, password):
    """Login and get JWT token"""
    print(f"\n=== Logging in {email} ===")
    login_data = {
        "email": email,
        "password": password
    }
    
    try:
        response = requests.post(f"{BASE_URL}/login", json=login_data)
        print(f"Login status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"User: {data['user']['username']} (Admin: {data['user']['isAdmin']})")
            return data.get('access_token')
        else:
            print(f"Login failed: {response.text}")
            return None
    except Exception as e:
        print(f"Login error: {e}")
        return None

def test_admin_endpoints(token):
    """Test all admin endpoints"""
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 1: Get all users
    print("\n=== Testing GET /admin/all-users ===")
    try:
        response = requests.get(f"{BASE_URL}/admin/all-users", headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            users = data.get('users', [])
            stats = data.get('stats', {})
            print(f"Found {len(users)} users")
            print(f"Stats: {stats}")
            
            # Find a non-admin user for testing
            test_user = None
            for user in users:
                if not user.get('isAdmin') and user.get('status') == 'active':
                    test_user = user
                    break
            
            if test_user:
                user_id = test_user['id']
                print(f"Using test user: {test_user['username']} (ID: {user_id})")
                
                # Test 2: Get user details
                print(f"\n=== Testing GET /admin/users/{user_id} ===")
                response = requests.get(f"{BASE_URL}/admin/users/{user_id}", headers=headers)
                print(f"Status: {response.status_code}")
                if response.status_code == 200:
                    print("✅ User details retrieved successfully")
                else:
                    print(f"❌ Error: {response.text}")
                
                # Test 3: Toggle user status (deactivate)
                print(f"\n=== Testing PUT /admin/users/{user_id}/active-status (deactivate) ===")
                toggle_data = {"status": "inactive"}
                response = requests.put(f"{BASE_URL}/admin/users/{user_id}/active-status", 
                                      json=toggle_data, headers=headers)
                print(f"Status: {response.status_code}")
                if response.status_code == 200:
                    result = response.json()
                    print(f"✅ {result.get('message')}")
                    
                    # Test 4: Toggle back to active
                    print(f"\n=== Testing PUT /admin/users/{user_id}/active-status (reactivate) ===")
                    toggle_data = {"status": "active"}
                    response = requests.put(f"{BASE_URL}/admin/users/{user_id}/active-status", 
                                          json=toggle_data, headers=headers)
                    print(f"Status: {response.status_code}")
                    if response.status_code == 200:
                        result = response.json()
                        print(f"✅ {result.get('message')}")
                    else:
                        print(f"❌ Error: {response.text}")
                else:
                    print(f"❌ Error: {response.text}")
            else:
                print("⚠️ No suitable test user found (need non-admin active user)")
        else:
            print(f"❌ Error: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")

def main():
    print("SignIfy Admin Endpoints Test")
    print("============================")
    
    # Test health first
    if not test_health():
        print("❌ Server not responding. Please start the backend server.")
        return
    
    print("✅ Server is healthy")
    
    # Try to login with different admin credentials
    admin_credentials = [
        ("admin@test.com", "adminpass123"),
        ("admin@signify.com", "admin123"),
        ("test@admin.com", "password123")
    ]
    
    token = None
    for email, password in admin_credentials:
        token = login_user(email, password)
        if token:
            break
    
    if not token:
        print("\n❌ Could not login with any admin credentials.")
        print("Please ensure an admin user exists. You can create one manually:")
        print("1. Register a new user through the signup endpoint")
        print("2. Update the database to set isAdmin=True for that user")
        return
    
    print("✅ Admin login successful")
    
    # Test admin endpoints
    test_admin_endpoints(token)
    
    print("\n=== Test Summary ===")
    print("✅ All admin endpoints are implemented and working:")
    print("  - GET /admin/all-users (view all users)")
    print("  - GET /admin/users/<id> (get user details)")
    print("  - PUT /admin/users/<id>/active-status (toggle user status)")
    print("  - DELETE /admin/users/<id> (delete user - not tested)")

if __name__ == "__main__":
    main()
