class Nobody
  def friendly_name
    'Please log in'
  end
  def is_store_admin?
    false
  end
  def is_admin?
    false
  end
  def is_store_admin_or_admin?
    false
  end
  def is_store_user?
    false
  end
  def store
    Store.new
  end
  def drafts(load=false)
    []
  end
  def submitted(load=false)
    []
  end
  def reviewing(load=false)
    []
  end
  def archived(load=false)
    []
  end
end
