from flask_wtf import FlaskForm
from wtforms.validators import Length, NumberRange
from wtforms import SubmitField, SelectField, StringField, TextAreaField, IntegerField
from flask_wtf.file import FileField, FileAllowed

def FormStorageCreate(parents, categories):
    class _FormStorageCreate(FlaskForm):
        parents_choices = [("-1", "")] + \
            [(parent.id, parent.title) for parent in parents]
        categories_choices = [(category.id, category.path) for category in categories]
        title = StringField("Название", validators=[Length(2, -1, "Название оборудования не может быть менее 2 символов")])
        parent_id = SelectField("Устанавливается на", choices=parents_choices, default="-1")
        category_id = SelectField("Категория", choices=categories_choices)
        description = TextAreaField("Описание")
        price = IntegerField("Стоимость/сутки (₽)", default=0, validators=[NumberRange(0, 100000, "Стоимость аренды должна быть более 0 и не более 100.000 рублей")])
        files = FileField("Фотографии", validators=[FileAllowed(["jpg", "jpeg", "png"], "Используйте файлы расширений .jpg, .jpeg или .png")], render_kw={"multiple": ""})
        create_submit = SubmitField("Добавить")
    return _FormStorageCreate()