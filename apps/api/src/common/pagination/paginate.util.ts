import { SelectQueryBuilder } from 'typeorm';
import { PaginatedResult, PaginationQueryDto } from './pagination.dto';

export async function paginateQuery<T>(
  queryBuilder: SelectQueryBuilder<T>,
  pagination: PaginationQueryDto,
): Promise<PaginatedResult<T>> {
  const page = Math.max(1, pagination.page || 1);
  const limit = Math.min(100, Math.max(1, pagination.limit || 20));
  const skip = (page - 1) * limit;

  queryBuilder.skip(skip).take(limit);

  const [items, total] = await queryBuilder.getManyAndCount();

  const totalPages = Math.ceil(total / limit) || 1;

  return {
    items,
    total,
    page,
    limit,
    totalPages,
  };
}
