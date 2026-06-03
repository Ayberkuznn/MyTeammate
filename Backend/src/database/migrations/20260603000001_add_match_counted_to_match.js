exports.up = function (knex) {
  return knex.schema.alterTable('Match', (table) => {
    table.boolean('match_counted').notNullable().defaultTo(false);
  });
};

exports.down = function (knex) {
  return knex.schema.alterTable('Match', (table) => {
    table.dropColumn('match_counted');
  });
};
