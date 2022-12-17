from flask_wtf import FlaskForm
from wtforms.validators import Length, NumberRange
from wtforms import SubmitField, SelectField, StringField, TextAreaField, IntegerField
from flask_wtf.file import FileField, FileAllowed

def FormStorageEdit(parents, categories, equipment):
    class _FormStorageEdit(FlaskForm):
        parents_choices = [("-1", "")] + \
            [(parent.id, parent.title) for parent in parents]
        categories_choices = [(category.id, category.path) for category in categories]
        title = StringField("Название", default=equipment.title, validators=[Length(2, -1, "Название оборудования не может быть менее 2 символов")])
        parent_id = SelectField("Устанавливается на", default=equipment.parent_id, choices=parents_choices)
        category_id = SelectField("Категория", default=equipment.category_id, choices=categories_choices)
        description = TextAreaField("Описание", default=equipment.description)
        price = IntegerField("Стоимость/сутки (₽)", default=equipment.price, validators=[NumberRange(0, 100000, "Стоимость аренды должна быть более 0 и не более 100.000 рублей")])
        count = IntegerField("Количество", default=equipment.count, validators=[NumberRange(0, 50, "Количество на сладе не может быть меньше 0 и более 50 штук")])
        edit_submit = SubmitField("Сохранить изменения")
    return _FormStorageEdit()