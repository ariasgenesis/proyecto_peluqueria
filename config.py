import os 
from dotenv import load_dotenv
load_dotenv() # cargar las variables de entorno 

class Config:
    MYSQL_HOST       = os.getenv('MYSQL_HOST') or os.getenv('MYSQLHOST')
    MYSQL_USER       = os.getenv('MYSQL_USER') or os.getenv('MYSQLUSER')
    MYSQL_PASSWORD   = os.getenv('MYSQL_PASSWORD') or os.getenv('MYSQLPASSWORD')
    MYSQL_DB         = os.getenv('MYSQL_DB') or os.getenv('MYSQL_DATABASE')
    MYSQL_PORT      = int(os.getenv('MYSQL_PORT', 3306))
    JWT_SECRET_KEY   = os.getenv('JWT_SECRET_KEY') or os.getenv('SECRET_KEY') or 'change-me'

