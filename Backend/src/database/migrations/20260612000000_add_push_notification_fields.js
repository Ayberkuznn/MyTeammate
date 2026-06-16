exports.up = function (knex) {
  return knex.schema
    .alterTable('User', (table) => {
      table.string('fcm_token');
    })
    .alterTable('Match', (table) => {
      table.boolean('reminder_sent').notNullable().defaultTo(false);
      table.boolean('eval_notif_sent').notNullable().defaultTo(false);
    });
};

exports.down = function (knex) {
  return knex.schema
    .alterTable('User', (table) => {
      table.dropColumn('fcm_token');
    })
    .alterTable('Match', (table) => {
      table.dropColumn('reminder_sent');
      table.dropColumn('eval_notif_sent');
    });
};
