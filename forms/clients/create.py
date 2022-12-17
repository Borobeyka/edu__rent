from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TelField, IntegerField, TextAreaField, DateField
from wtforms.validators import Length, NumberRange

class FormClientsCreate(FlaskForm):
    name = StringField("Имя", validators=[Length(2, -1, "Имя не может быть короче 2 символов")])
    surname = StringField("Фамилия")
    phone = TelField("Телефон", validators=[Length(11, 11, "Телефон введен неверно")])
    telegram = StringField("Telegram")
    discount = IntegerField("Скидка (%)", default=0, validators=[NumberRange(0, 100, "Размер скидки от 0% до 100%")])
    comment = TextAreaField("Комментарий")
    
    create_submit = SubmitField("Далее")