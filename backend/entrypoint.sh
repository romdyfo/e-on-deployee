#!/bin/sh
echo "--- ENTRYPOINT SCRIPT STARTED ---"

# docker-compose.yml에서 주입된 환경변수를 직접 사용
# DB_HOST 변수가 없으면 기본값으로 'mysql'을 사용
DB_HOST=${DB_HOST:-mysql}
DB_PORT=${DB_PORT:-3306}

echo "Waiting for database at $DB_HOST:$DB_PORT..."

# nc 명령어로 DB 포트가 열릴 때까지 1초마다 확인
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done

echo "Database started"

echo "Running database migrations..."
# 마이그레이션 실행
npx sequelize-cli db:migrate

echo "Running database seeders..."
# 2. seeders 폴더의 모든 시더 파일 실행
npx sequelize-cli db:seed:all

# 마이그레이션이 끝나면 원래 CMD 실행
echo "Starting Server..."
exec "$@"