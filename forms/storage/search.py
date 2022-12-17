from flask_wtf import FlaskForm
from wtforms import SubmitField, SelectField, StringField, BooleanField

def FormStorageSearch(categories):
    class _FormStorageSearch(FlaskForm):
        choices = [("-1", "Все категории")] + \
            [(category.id, category.path) for category in categories]
        category_id = SelectField("", choices=choices, default="-1")
        query = StringField("", render_kw={"placeholder": "Введите запрос..."})
        search_submit = SubmitField("Поиск")
    return _FormStorageSearch()