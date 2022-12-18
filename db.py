from werkzeug.security import generate_password_hash, check_password_hash
from psycopg2.extras import RealDictCursor, RealDictRow
from dotmap import DotMap

def convert(data):
    a = []
    if isinstance(data, RealDictRow):
        return DotMap(data)
    for item in data:
        a.append(DotMap(item))
    return a

class DB():
    def __init__(self, db):
        self.db = db
        self.cursor = db.cursor(cursor_factory=RealDictCursor)

    def estimate_set_payed(self, estimate_id):
        self.cursor.execute("UPDATE estimates SET is_payed=true WHERE id=%s",
            (estimate_id,))
        self.db.commit()

    def get_estimates_details_by_id(self, estimate_id):
        self.cursor.execute("SELECT * FROM get_estimates_details_by_id(%s)",
            (estimate_id,))
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)
    
    def get_estimate_by_id(self, estimate_id):
        self.cursor.execute("SELECT * FROM get_estimate_by_id(%s)",
            (estimate_id,))
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)
    
    def equipments_update(self, data):
        query = """
            BEGIN;
                UPDATE equipments SET parent_id=%s, title=%s, category_id=%s, description=%s, count=%s WHERE id=%s;
                INSERT INTO prices VALUES (DEFAULT, %s, %s, DEFAULT);
            COMMIT;
        """
        self.cursor.execute(query, (data.parent_id, data.title, data.category_id, data.description, data.count, data.equipment_id, data.equipment_id, data.price))
    
    def create_equipment(self, data):
        self.cursor.execute("SELECT * FROM create_equipment(%s, %s, %s, %s, %s::varchar[])",
            (data.parent_id, data.title, data.category_id, data.description, data.images))
        self.db.commit()
        response = self.cursor.fetchone()
        self.cursor.execute("INSERT INTO prices VALUES (DEFAULT, %s, %s, DEFAULT); commit;",
            (response.get("new_id"), data.price))
        if not response:
            return False
        return convert(response)
    
    def get_price_history_by_euipment_id(self, equipment_id):
        self.cursor.execute("SELECT * FROM get_price_history_by_equipment_id(%s)",
            (equipment_id,))
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)

    def delete_estimate_by_id(self, estimate_id):
        query = '''
            BEGIN;
                DELETE FROM estimates_details WHERE estimate_id = %s;
                DELETE FROM estimates WHERE id = %s;
            COMMIT;
        '''
        self.cursor.execute(query, (estimate_id, estimate_id,))
    
    def create_estimate_details(self, item):
        self.cursor.execute("CALL create_estimate_details(%s, %s, %s, %s)",
            (item.estimate_id, item.equipment_id, item.price_id, item.count))
        self.db.commit()
    
    def create_estimate(self, data):
        self.cursor.execute("SELECT * FROM create_estimate(%s, %s, %s, %s, %s, %s)",
            (data.creator_id, data.client_id, data.project, data.start_date, data.close_date, data.comment))
        self.db.commit()
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)

    def get_equipment_by_id(self, equipment_id):
        self.cursor.execute("SELECT * FROM get_equipment_by_id(%s)",
            (equipment_id,))
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)
    
    def get_equipments(self, search):
        self.cursor.execute("SELECT * FROM get_equipments(%s, %s)",
            (search.category_id, search.query))
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)
    
    def get_categories_tree(self):
        self.cursor.execute("SELECT * FROM get_categories_tree()")
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)

    def create_client(self, data):
        self.cursor.execute("SELECT * FROM create_client(%s, %s, %s, %s, %s, %s)",
            (data.name, data.surname, data.phone, data.telegram, data.comment, data.discount))
        self.db.commit()
        response = self.cursor.fetchone()
        self.cursor.execute("INSERT INTO passports_data (client_id) VALUES (%s); commit;",
            (response.get("new_id"),))
        if not response:
            return False
        return convert(response)
    
    def client_personal_update(self, client):
        self.cursor.execute("UPDATE clients SET name=%s, surname=%s, phone=%s, telegram=%s, comment=%s, discount=%s WHERE id=%s",
            (client.name, client.surname, client.phone, client.telegram, client.comment, client.discount, client.id))
        self.db.commit()
        
    def client_passport_update(self, client):
        self.cursor.execute("UPDATE passports_data SET series=%s, number=%s, issued_by=%s, issue_date=%s, division_code=%s, registration_address=%s WHERE client_id=%s",
            (client.series, client.number, client.issued_by, client.issue_date, client.division_code, client.registration_address, client.id))
        self.db.commit()
    
    def get_all_clients_details(self, data):
        self.cursor.execute("SELECT * FROM get_all_clients_details(%s, %s, %s)", 
            (data.field_name, data.query, data.is_payed))
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)
    
    def get_all_clients_short(self):
        self.cursor.execute("SELECT * FROM get_all_clients_short()")
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)

    def get_filtered_estimates(self, data):
        self.cursor.execute("SELECT * FROM get_filtered_estimates(%s, %s, %s)",
            (data.start_date, data.close_date, data.client_id))
        response = self.cursor.fetchall()
        if not response:
            return False
        return convert(response)
    
    def get_client_by_id(self, client_id):
        self.cursor.execute("SELECT * FROM get_client_by_id(%s)", (client_id,))
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)
    
    def get_user_by_login(self, data):
        self.cursor.execute("SELECT * FROM users WHERE login=%s", (data.login.data,))
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)

    def get_user(self, user_id):
        self.cursor.execute("SELECT * FROM users WHERE id=%s", (user_id,))
        response = self.cursor.fetchone()
        if not response:
            return False
        return convert(response)