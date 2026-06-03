exports.up = function(knex) {
  return knex.schema.alterTable('Match', (table) => {
    table.timestamp('evaluated_at', { useTz: true }).nullable().defaultTo(null);
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('Match', (table) => {
    table.dropColumn('evaluated_at');
  });
};
