from flask_wtf import FlaskForm
from wtforms import SubmitField, SelectField, DateField

def FormEstimatesFilters(clients):
    class _FormEstimatesFilters(FlaskForm):
        choices = [(-1, "")] + \
            [(client.id, client.surname + " " + client.name) for client in clients]
        start_date = DateField("Дата выдачи")
        close_date = DateField("Дата возврата")
        client_id = SelectField("Клиент", choices=choices)
        submit = SubmitField("Применить")
    return _FormEstimatesFilters()