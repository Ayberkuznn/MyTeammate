exports.up = function(knex) {
  return knex.schema.createTable('User', (table) => {
    table.increments('user_id').primary();
    table.string('Name').notNullable();
    table.string('Surname').notNullable();
    table.string('Email').notNullable().unique();
    table.string('Password').notNullable();
    table.string('Phone_number').notNullable().unique();
    table.date('Birthday').notNullable();
    table.string('City').notNullable();
    table.string('District').notNullable();
    table.string('Position').notNullable();
    table.string('Foot'); // Sağ/Sol ayak bilgisi için
    table.decimal('avg_rating', 3, 2).defaultTo(0);
    table.integer('Penalty_score').defaultTo(0);
    table.integer('total_match').defaultTo(0);
    table.string('profile_photo');
    table.date('created_at').defaultTo(knex.fn.now());
  });
};

exports.down = function(knex) {
  return knex.schema.dropTableIfExists('User');
};