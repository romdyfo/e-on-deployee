# backend/Dockerfile (최종 수정본)

# ==========================================================
# STAGE 1: Build Stage (빌드 전용 스테이지, 이름은 builder)
# ==========================================================
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
# 개발용, 프로덕션용 모든 의존성 설치
RUN npm install
COPY . .


# ==========================================================
# STAGE 2: Final Stage (최종 실행용 스테이지)
# ==========================================================
FROM node:20-alpine 

# netcat(nc) 도구 설치 (DB 연결 확인용)
RUN apk add --no-cache netcat-openbsd

WORKDIR /app

# --- 완성된 builder 스테이지에서 필요한 파일만 가져온다---
COPY --from=builder /app/package*.json ./
# 프로덕션에 필요한 의존성만 설치해서 용량을 줄인다
RUN npm install --omit=dev
# 빌드된 소스코드 전체를 가져온다
COPY --from=builder /app .

# entrypoint 스크립트 복사 및 실행 권한 부여
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# 컨테이너 시작점과 기본 명령어 지정
ENTRYPOINT ["entrypoint.sh"]
CMD ["node", "index.js"]