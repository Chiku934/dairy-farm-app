import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { BmcService } from './bmc.service';
import { CreateBmcIntakeDto } from './dto/create-bmc-intake.dto';
import { BmcQueryDto } from './dto/bmc-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('bmc')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class BmcController {
  constructor(private readonly bmcService: BmcService) {}

  @Post('intake')
  @RequirePermissions('bmc:write')
  async createIntake(
    @Body() dto: CreateBmcIntakeDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.bmcService.createIntake(dto, user);
  }

  @Get('intake')
  @RequirePermissions('bmc:read')
  async findAllIntakes(@Query() query: BmcQueryDto) {
    return this.bmcService.findAllIntakes(query);
  }

  @Get('balance')
  @RequirePermissions('bmc:read')
  async getTankBalance() {
    return this.bmcService.getTankBalance();
  }

  @Get('intake/:id')
  @RequirePermissions('bmc:read')
  async findOneIntake(@Param('id') id: string) {
    return this.bmcService.findOneIntake(id);
  }
}
