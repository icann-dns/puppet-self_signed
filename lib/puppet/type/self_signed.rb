Puppet::Type.newtype(:self_signed) do
  @doc = 'This type is used to create a self signed certificate'

  ensurable
  def munge_boolean(value)
    case value
    when true, 'true', :true
      :true
    when false, 'false', :false
      :false
    else
      fail("munge_boolean only takes booleans")
    end
  end

  newparam(:cn, :namevar => true) do
    desc 'the certificate cn'
    newvalues(/[\w\-\.]+/)
  end

  newproperty(:bits ) do
    desc 'the number of bits'
    defaultto(2048)
    newvalues(/\d+/)
  end

  newproperty(:email) do
    desc 'The contact email address'
  end

  newproperty(:country) do
    desc 'The certificate country'
  end

  newproperty(:state) do
    desc 'The certificate state'
  end

  newproperty(:locality) do
    desc 'The certificate locality'
  end

  newproperty(:organisation) do
    desc 'The certificate organisation'
  end

  newproperty(:unit) do
    desc 'The certificate unit'
  end

  newproperty(:days) do
    desc 'The number of days for the certificate'
    defaultto(3650)  
    munge do |value|
      value.to_i
    end
    newvalues(/\d+/)
  end

  newparam(:update, :boolean => true) do
    desc 'Should we update the certificate when its due to expire'
    munge do |value|
      @resource.munge_boolean(value)
    end
    newvalues(:true, :false)
  end

  newparam(:update_days) do
    desc 'The number of days before expiry we should update the cert'
    defaultto(10)  
    newvalues(/\d+/)
  end

end
