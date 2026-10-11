import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should return operational status', () => {
    const res = controller.check();
    expect(res.status).toBe('ok');
    expect(res.service).toBe('dairy-farm-api');
    expect(res).toHaveProperty('uptimeSeconds');
  });
});
