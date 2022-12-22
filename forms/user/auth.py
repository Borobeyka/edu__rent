from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, PasswordField
from wtforms.validators import Length

class FormUserAuth(FlaskForm):
    login = StringField("Логин:", validators=[Length(4, -1, "Логин не может быть короче 4 символов")])
    pswd = PasswordField("Пароль:", validators=[Length(6, -1, "Пароль не может быть короче 6 символов")])
    submit = SubmitField("Авторизация")