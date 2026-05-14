const pool = require('../config/db');

async function getFields({ city, district }) {
  const cleanCity     = typeof city     === 'string' ? city.trim()     : null;
  const cleanDistrict = typeof district === 'string' ? district.trim() : null;

  if (!cleanCity) return { status: 400, body: { error: 'İl parametresi zorunludur.' } };

  let query = `SELECT field_id, field_name, city, district, address, capacity,
                      has_shower, has_parking, phone_number
               FROM "Field"`;
  const params = [];

  if (cleanCity && cleanDistrict) {
    query += ` WHERE city = $1 AND district = $2`;
    params.push(cleanCity, cleanDistrict);
  } else if (cleanCity) {
    query += ` WHERE city = $1`;
    params.push(cleanCity);
  }

  query += ` ORDER BY field_name`;

  const result = await pool.query(query, params);

  return {
    status: 200,
    body: result.rows.map((r) => ({
      id:          r.field_id,
      name:        r.field_name,
      city:        r.city,
      district:    r.district,
      address:     r.address,
      capacity:    r.capacity,
      hasShower:   r.has_shower,
      hasParking:  r.has_parking,
      phoneNumber: r.phone_number,
    })),
  };
}

module.exports = { getFields };
