# User is a factory/helper for creating User type Personas
class User
  def self.new
    persona = Persona.new
    persona.type = "User"
    persona
  end
  
  def self.create(params)
    persona = Persona.new
    persona.type = "User"
    persona.email = params[:email] if params[:email]?
    persona.password = params[:password] if params[:password]?
    persona.password_confirmation = params[:password_confirmation] if params[:password_confirmation]?
    persona.api_key = params[:api_key] if params[:api_key]?
    persona.api_secret = params[:api_secret] if params[:api_secret]?
    persona.save
    persona
  end
  
  def self.find(id)
    Persona.find_by(id: id, type: "User")
  end
  
  def self.find_by(params)
    updated_params = params.to_h
    updated_params[:type] = "User"
    Persona.find_by(updated_params)
  end
  
  def self.find_by!(params)
    result = find_by(params)
    raise "User not found" unless result
    result
  end
  
  def self.all
    Persona.where(type: "User")
  end
end