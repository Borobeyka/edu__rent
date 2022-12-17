from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TelField, TextAreaField, DateField
from wtforms.validators import Length

def FormClientsPassport(client):
    class _FormClientsPassport(FlaskForm):
        series = StringField("Серия", default=client.series, validators=[Length(4, 4, "Длина серии паспорта должна быть 4 символа")])
        number = StringField("Номер", default=client.number, validators=[Length(6, 6, "Длина номера паспорта должна быть 4 символа")])
        issued_by = StringField("Кем выдан", default=client.issued_by, validators=[Length(-1, 64, "Длина названия выдающего подразделения должна быть менее 64 символов")])
        issue_date = DateField("Дата выдачи", default=client.issue_date)
        division_code = StringField("Код подразделения", default=client.division_code, validators=[Length(7, 7, "Код подразделения введен неверно")])
        registration_address = StringField("Адрес рег-ии", default=client.registration_address, validators=[Length(-1, 128, "Адрес регистрации должен быть менее 128 символов")])

        passport_submit = SubmitField("Сохранить изменения")
    return _FormClientsPassport()