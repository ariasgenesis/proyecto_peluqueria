class LoginModel:
    @staticmethod
    def obtener_por_username(mysql, username):
        cursor = mysql.connection.cursor()
        cursor.execute(
            "SELECT usu_id, usu_username, usu_password, usu_email, usu_rol, usu_estado "
            "FROM usuarios WHERE usu_username = %s AND usu_estado = %s",
            (username, 'activo')
        )
        usuario = cursor.fetchone()
        cursor.close()
        if not usuario:
            return None

        return {
            'id_usuario': usuario[0],
            'username': usuario[1],
            'password': usuario[2],
            'email': usuario[3],
            'rol': usuario[4],
            'estado': usuario[5]
        }

    @staticmethod
    def actualizar_password(mysql, id_usuario, password_hash):
        cursor = mysql.connection.cursor()
        cursor.execute(
            "UPDATE usuarios SET usu_password = %s WHERE usu_id = %s",
            (password_hash, id_usuario)
        )
        mysql.connection.commit()
        cursor.close()
