import { PartialType } from '@nestjs/swagger';
import { CreateRationDto } from './create-ration.dto';

export class UpdateRationDto extends PartialType(CreateRationDto) {}
