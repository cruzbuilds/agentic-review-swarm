from models import Store


def upgrade_prompt_needed(store: Store, user_id: int) -> bool:
    """Show the upgrade prompt when a free user has hit the limit."""
    user = store.users[user_id]
    if user.plan != "free":
        return False
    return len(store.active_projects(user_id)) >= 3


def downgrade_to_free(store: Store, user_id: int) -> None:
    """Team plan ended. Everything beyond the free limit is archived, newest first,
    so the account is inside the limit the moment the plan changes."""
    user = store.users[user_id]
    user.plan = "free"
    active = sorted(store.active_projects(user_id), key=lambda p: p.id, reverse=True)
    for project in active[3:]:
        project.status = "archived"
