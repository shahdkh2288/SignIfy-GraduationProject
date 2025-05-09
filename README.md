SignIfy Backend Setup
Prerequisites

Python 3.x
PostgreSQL 17 (Windows: https://www.postgresql.org/download/windows/)
Git

Setup

Clone:
git clone https://github.com/<your-username>/SignIfy-GraduationProject.git
cd SignIfy-GraduationProject/backend


Python:
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt


Install PostgreSQL:

Download installer, include Command Line Tools.
Add C:\Program Files\PostgreSQL\17\bin to PATH.
Verify: psql --version


Create database:
psql -U postgres

CREATE DATABASE signifydb WITH ENCODING 'UTF8';
CREATE USER flaskuser WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE signifydb TO flaskuser;

Or use pgAdmin 4.

Set .env in backend/:
DATABASE_URL=postgresql://flaskuser:yourpassword@localhost:5432/signifydb
JWT_SECRET_KEY=your-secret-key
PGCLIENTENCODING=UTF8


Initialize migrations:
cd app
$env:FLASK_APP = "app"
flask db init
flask db migrate -m "Initial schema with User table"
flask db upgrade


Run:
flask run



Testing

API: POST /signup, POST /login, GET /protected (with Bearer token).
Flutter: http://10.0.2.2:5000 (emulator) or testing server.

