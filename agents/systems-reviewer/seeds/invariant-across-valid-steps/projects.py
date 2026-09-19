from models import FREE_ACTIVE_LIMIT, Forbidden, NotFound, PlanLimit, Project, Store


def create_project(store: Store, user_id: int, name: str) -> Project:
    user = store.users[user_id]
    if user.plan == "free" and len(store.active_projects(user_id)) >= FREE_ACTIVE_LIMIT:
        raise PlanLimit(f"free plan allows {FREE_ACTIVE_LIMIT} active projects")
    project = Project(id=store.new_id(), owner_id=user_id, name=name.strip())
    store.projects[project.id] = project
    return project


def archive_project(store: Store, user_id: int, project_id: int) -> Project:
    project = _owned(store, user_id, project_id)
    project.status = "archived"
    return project


def restore_project(store: Store, user_id: int, project_id: int) -> Project:
    """Bring an archived project back. Only the owner can do this."""
    project = _owned(store, user_id, project_id)
    if project.status != "archived":
        raise ValueError("only archived projects can be restored")
    project.status = "active"
    return project


def _owned(store: Store, user_id: int, project_id: int) -> Project:
    project = store.projects.get(project_id)
    if project is None:
        raise NotFound(project_id)
    if project.owner_id != user_id:
        raise Forbidden(project_id)
    return project
