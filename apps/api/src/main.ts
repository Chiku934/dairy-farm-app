import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable CORS for mobile development & Web preview
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global API Versioning prefix
  app.setGlobalPrefix('api/v1');

  // Global Filters & Interceptors
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new TransformInterceptor(),
  );

  // Request Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger / OpenAPI documentation
  const config = new DocumentBuilder()
    .setTitle('Dairy Farm Management System API')
    .setDescription(
      'Enterprise REST API specifications for farm, milk processing, and business operations.',
    )
    .setVersion('1.0')
    .addTag('Health & Diagnostics', 'Liveness probes and database connection verification')
    .addTag('Authentication & Sessions', 'JWT token lifecycle, login, refresh, profile and session revocation')
    .addTag('Farm Settings & Identity', 'Master farm identity, technical constants, and default utility rates')
    .addTag('Users, Roles & Permissions', 'Staff accounts, role assignments, and granular RBAC controls')
    .addTag('Master Data & Lookups', 'Standard units of measurement, taxonomy lookups, and categorizations')
    .addTag('Audit Logs & Compliance', 'Immutable system audit trails and regulatory activity history')
    .addBearerAuth({
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT',
      name: 'JWT',
      description: 'Enter JWT bearer token',
      in: 'header',
    })
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`API Server listening on: http://localhost:${port}/api/v1`);
  logger.log(`Swagger OpenAPI available at: http://localhost:${port}/api/docs`);
}

bootstrap();
