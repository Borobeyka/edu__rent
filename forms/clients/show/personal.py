from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TelField, IntegerField, TextAreaField
from wtforms.validators import Length, NumberRange

def FormClientsPersonal(client):
    class _FormClientsPersonal(FlaskForm):
        name = StringField("Имя", default=client.name, validators=[Length(2, -1, "Имя не может быть короче 2 символов")])
        surname = StringField("Фамилия", default=client.surname)
        phone = TelField("Телефон", default=client.phone, validators=[Length(11, 11, "Телефон введен неверно")])
        telegram = StringField("Telegram", default=client.telegram)
        discount = IntegerField("Скидка (%)", default=client.discount, validators=[NumberRange(0, 100, "Размер скидки от 0% до 100%")])
        comment = TextAreaField("Комментарий", default=client.comment)
        
        personal_submit = SubmitField("Сохранить изменения")
    return _FormClientsPersonal()