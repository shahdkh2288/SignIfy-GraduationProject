"""Initial schema with User table

    Revision ID: dca92ded2cdc
    Revises: 
    Create Date: 2025-05-09 18:14:48.247292
    """
from alembic import op
import sqlalchemy as sa

revision = 'dca92ded2cdc'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
        op.create_table('user',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=80), nullable=False),
        sa.Column('email', sa.String(length=120), nullable=False),
        sa.Column('password', sa.String(length=128), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='active'),
        sa.Column('age', sa.Integer(), nullable=False),
        sa.Column('isAdmin', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('username', name='user_username_key'),
        sa.UniqueConstraint('email', name='user_email_key')
        )
        with op.batch_alter_table('user', schema=None) as batch_op:
            batch_op.create_index(batch_op.f('ix_user_email'), ['email'], unique=True)
            batch_op.create_index(batch_op.f('ix_user_username'), ['username'], unique=True)

def downgrade():
        with op.batch_alter_table('user', schema=None) as batch_op:
            batch_op.drop_index(batch_op.f('ix_user_username'))
            batch_op.drop_index(batch_op.f('ix_user_email'))
            op.drop_table('user')