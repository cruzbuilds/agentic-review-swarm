from models import Forbidden, NotFound, Project, Store


def transfer_project(store: Store, from_user_id: int, to_user_id: int, project_id: int) -> Project:
    """Hand a project to another user. The receiver becomes the owner; the sender loses access.

    Used when someone leaves a team or when a contractor hands work back to a client.
    """
    project = store.projects.get(project_id)
    if project is None:
        raise NotFound(project_id)
    if project.owner_id != from_user_id:
        raise Forbidden(project_id)
    if to_user_id not in store.users:
        raise NotFound(to_user_id)
    project.owner_id = to_user_id
    return project
