# Etapa de build
FROM node:20-alpine AS build

# Crea directorio de trabajo
WORKDIR /app

# Copia package.json y package-lock.json
COPY package*.json ./

# Instala dependencias
RUN npm install

# Copia el resto del código
COPY . .

# Compila
RUN npm run build

# Ejecuta
FROM node:20-alpine

WORKDIR /app

# Copia desde build - dependencias solo en producción
COPY package*.json ./
RUN npm install --only=production

# Copia de artefactos compilados
COPY --from=build /app/dist ./dist

# Puerto por defecto
EXPOSE 3000

# Comando de inicio
CMD ["node", "dist/main.js"]