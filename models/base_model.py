from datetime import date, datetime, time


class BaseModel:
    table = None
    id_field = None
    id_column = None
    fields = []
    writable_fields = None
    search_fields = []
    filter_fields = {}
    soft_delete_column = None
    soft_delete_value = None

    def __init__(self, **kwargs):
        for field, _column, _type in self.fields:
            setattr(self, field, kwargs.get(field))

    def to_dict(self):
        data = {}
        for field, _column, field_type in self.fields:
            value = getattr(self, field)
            if field_type == 'decimal' and value is not None:
                value = float(value)
            elif field_type in {'date', 'time', 'datetime'} and value is not None:
                value = str(value)
            elif isinstance(value, (datetime, date, time)):
                value = str(value)
            data[field] = value
        return data

    @classmethod
    def _columns(cls):
        return ', '.join(column for _field, column, _type in cls.fields)

    @classmethod
    def _field_column(cls, field_name):
        for field, column, _type in cls.fields:
            if field == field_name:
                return column
        return None

    @classmethod
    def _writable(cls):
        if cls.writable_fields is not None:
            allowed = set(cls.writable_fields)
            return [field for field in cls.fields if field[0] in allowed]
        return [field for field in cls.fields if field[0] != cls.id_field and field[2] != 'readonly']

    @classmethod
    def _from_row(cls, row):
        values = {field[0]: row[index] for index, field in enumerate(cls.fields)}
        return cls(**values).to_dict()

    @classmethod
    def _where_clause(cls, filters=None, search=None, include_deleted=False):
        clauses = []
        params = []
        filters = filters or {}

        if cls.soft_delete_column and not include_deleted:
            active_value = 'activo'
            if cls.soft_delete_value in {'cancelada', 'cancelado'}:
                clauses.append(f"{cls.soft_delete_column} <> %s")
                params.append(cls.soft_delete_value)
            else:
                clauses.append(f"{cls.soft_delete_column} = %s")
                params.append(active_value)

        for public_name, column in cls.filter_fields.items():
            value = filters.get(public_name)
            if value not in (None, ''):
                clauses.append(f"{column} = %s")
                params.append(value)

        if search and cls.search_fields:
            search_parts = [f"{column} LIKE %s" for column in cls.search_fields]
            clauses.append('(' + ' OR '.join(search_parts) + ')')
            params.extend([f"%{search}%"] * len(cls.search_fields))

        if not clauses:
            return '', params
        return ' WHERE ' + ' AND '.join(clauses), params

    @classmethod
    def listar_todos(cls, mysql, page, per_page, filters=None, search=None, include_deleted=False):
        where_sql, params = cls._where_clause(filters, search, include_deleted)
        cursor = mysql.connection.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {cls.table}{where_sql}", tuple(params))
        total = cursor.fetchone()[0]
        offset = (page - 1) * per_page
        cursor.execute(
            f"SELECT {cls._columns()} FROM {cls.table}{where_sql} ORDER BY {cls.id_column} DESC LIMIT %s OFFSET %s",
            tuple(params + [per_page, offset])
        )
        rows = cursor.fetchall()
        cursor.close()
        return {
            'data': [cls._from_row(row) for row in rows],
            'total': total,
            'page': page,
            'per_page': per_page,
            'total_pages': (total + per_page - 1) // per_page if total else 0
        }

    @classmethod
    def obtener_por_id(cls, mysql, record_id):
        cursor = mysql.connection.cursor()
        cursor.execute(f"SELECT {cls._columns()} FROM {cls.table} WHERE {cls.id_column} = %s", (record_id,))
        row = cursor.fetchone()
        cursor.close()
        return cls._from_row(row) if row else None

    @classmethod
    def crear(cls, mysql, **data):
        writable = [field for field in cls._writable() if field[0] in data]
        columns = ', '.join(column for _field, column, _type in writable)
        placeholders = ', '.join(['%s'] * len(writable))
        values = tuple(data[field] for field, _column, _type in writable)
        cursor = mysql.connection.cursor()
        cursor.execute(f"INSERT INTO {cls.table} ({columns}) VALUES ({placeholders})", values)
        mysql.connection.commit()
        record_id = cursor.lastrowid
        cursor.close()
        return cls.obtener_por_id(mysql, record_id)

    @classmethod
    def actualizar(cls, mysql, record_id, **data):
        writable_names = {field[0] for field in cls._writable()}
        writable = [field for field in cls.fields if field[0] in writable_names and field[0] in data]
        if not writable:
            return cls.obtener_por_id(mysql, record_id)
        assignments = ', '.join(f"{column} = %s" for _field, column, _type in writable)
        values = tuple(data[field] for field, _column, _type in writable) + (record_id,)
        cursor = mysql.connection.cursor()
        cursor.execute(f"UPDATE {cls.table} SET {assignments} WHERE {cls.id_column} = %s", values)
        mysql.connection.commit()
        affected = cursor.rowcount
        cursor.close()
        # Si affected==0 puede ser porque los datos eran idénticos (MySQL no cuenta esa fila).
        # En ese caso el registro sigue existiendo, así que lo retornamos igual.
        return cls.obtener_por_id(mysql, record_id)

    @classmethod
    def eliminar(cls, mysql, record_id):
        cursor = mysql.connection.cursor()
        if cls.soft_delete_column and cls.soft_delete_value:
            cursor.execute(f"UPDATE {cls.table} SET {cls.soft_delete_column} = %s WHERE {cls.id_column} = %s", (cls.soft_delete_value, record_id))
        else:
            cursor.execute(f"DELETE FROM {cls.table} WHERE {cls.id_column} = %s", (record_id,))
        mysql.connection.commit()
        affected = cursor.rowcount
        cursor.close()
        return affected > 0
