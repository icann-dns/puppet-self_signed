require 'openssl'
Puppet::Type.type(:self_signed).provide(:linux ) do
  
  defaultfor :kernel => 'Linux'
  mk_resource_methods
  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    results     = Array.new
    prefix      = '/etc/ssl/certs'
    subject_map = { 'CN' => :name, 'OU' => :unit, 'O' => :organisation, 'L' => :locality, 'ST' => :state, 'C' => :country} 

    if File.exist?(prefix) then
      Dir.foreach('/etc/ssl/certs') do |cert_file|
        if cert_file.start_with?('puppet_self_signed_') then
          raw = File.read(prefix + '/' + cert_file)
          cert = OpenSSL::X509::Certificate.new(raw)
          Puppet.debug("Collecting #{cert_file}")
          result = { :ensure => :present }
          cert.subject.to_a.each do |subject_entry|
            Puppet.debug("Collecting #{subject_entry[0]} = #{subject_entry[1]}")
            result[subject_map[subject_entry[0]]] = subject_entry[1]
          end
          result[:bits] = cert.public_key.n.num_bytes * 8
          result[:days] = ((cert.not_after - cert.not_before)/24/60/60).to_i
          if cert.not_after < Time.now + 465 * 24 * 60 * 60 then
            Puppet.debug("cert expiring #{cert.subject}: #{cert.not_after}")
          end
          results << new(result)
        end
      end
    end
    results
  end

  def flush
    prefix    = 'puppet_self_signed_'
    base_path = '/etc/ssl'
    cert_file = base_path + '/certs/' + prefix + @resource[:name] + '.pem'
    key_file  = base_path + '/private/' + prefix + @resource[:name] + '.key'
    key       = nil
    cert      = nil

    subject   = "/CN=#{@resource[:name]}"
    subject   = "#{subject}/emailAddress/#{@resource[:email]}" if @resource[:email]
    subject   = "/OU=#{@resource[:unit]}#{subject}"            if @resource[:unit]
    subject   = "/O=#{@resource[:organisation]}#{subject}"     if @resource[:organisation]
    subject   = "/L=#{@resource[:locality]}#{subject}"         if @resource[:locality]
    subject   = "/ST=#{@resource[:state]}#{subject}"           if @resource[:state]
    subject   = "/C=#{@resource[:country]}#{subject}"          if @resource[:country]

    Puppet.debug("Flushing #{subject}")

    ['','/certs', '/private'].each do |subdir| 
      if ! File.exists?(base_path + subdir) then
        Dir.mkdir(base_path + subdir)
      end
    end
    if File.exists?(key_file) then
      raw = File.read(key_file) 
      key = OpenSSL::PKey::RSA.new(raw)
    else 
      key = OpenSSL::PKey::RSA.new(@resource[:bits])
      File.write(key_file, key.to_pem)
    end

    cert            = OpenSSL::X509::Certificate.new
    cert.subject    = cert.issuer = OpenSSL::X509::Name.parse(subject)
    cert.not_before = Time.now
    cert.not_after  = Time.now + @resource[:days] * 24 * 60 * 60
    cert.public_key = key.public_key
    cert.serial     = 0x0
    cert.version    = 2

    ef                     = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate  = cert
    cert.extensions = [
      ef.create_extension("basicConstraints","CA:TRUE", true),
      ef.create_extension("subjectKeyIdentifier", "hash"),
    ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                          "keyid:always,issuer:always")
    
    cert.sign(key, OpenSSL::Digest::SHA1.new)
    File.write(cert_file, cert.to_pem)
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
