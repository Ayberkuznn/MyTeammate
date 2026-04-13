/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Match', (table) => {
    table.increments('match_id').primary();
    
    // Foreign Key: Maçı oluşturan kullanıcı (User tablosundaki user_id'ye bağlı)
    table.integer('Creator_id').unsigned().notNullable()
      .references('user_id').inTable('User')
      .onDelete('CASCADE'); // Kullanıcı silinirse maç da silinsin mi? (İsteğe bağlı)

    table.date('Date').notNullable();
    table.time('Time').notNullable();

    // Foreign Key: Maçın yapılacağı saha (Field tablosundaki field_id'ye bağlı)
    // NOT: Önce Field tablosunu oluşturmuş olmalısın!
    table.integer('field_id').unsigned().notNullable()
      .references('field_id').inTable('Field')
      .onDelete('SET NULL');

    table.integer('required_players').defaultTo(10);
    table.integer('min_point_required').defaultTo(0);
    table.decimal('price_per_person', 10, 2);
    table.string('status').defaultTo('pending'); // pending, active, finished, cancelled
    
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Match');
};