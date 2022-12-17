from flask import request, url_for, g
from db import *

def storage_show_dlc(*args, **kwargs):
    db = DB(g.link_db)
    equipment_id = request.view_args["equipment_id"]
    equipment = db.get_equipment_by_id(equipment_id)
    return [{
        "text": equipment.title,
        "url": url_for("storage_show", equipment_id=equipment_id)
    }]

def storage_edit_dlc(*args, **kwargs):
    db = DB(g.link_db)
    equipment_id = request.view_args["equipment_id"]
    equipment = db.get_equipment_by_id(equipment_id)
    return [{
        "text": equipment.title,
        "url": url_for("storage_show", equipment_id=equipment_id)
    }]

def estimates_show_dlc(*args, **kwargs):
    db = DB(g.link_db)
    estimate_id = request.view_args["estimate_id"]
    estimate = db.get_estimate_by_id(estimate_id)
    return [{
        "text": "{0} от {1} [{2} {3}]".format(
            estimate.project,
            estimate.start_date,
            estimate.client_surname,
            estimate.client_name
        ),
        "url": url_for("estimates_show", estimate_id=estimate_id)
    }]