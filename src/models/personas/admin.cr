# Admin is a factory/helper for creating Admin type Personas
class Admin
  def self.new
    persona = Persona.new
    persona.type = "Admin"
    persona
  end
  
  def self.create(params)
    persona = Persona.new
    persona.type = "Admin"
    persona.email = params[:email] if params[:email]?
    persona.password = params[:password] if params[:password]?
    persona.password_confirmation = params[:password_confirmation] if params[:password_confirmation]?
    persona.api_key = params[:api_key] if params[:api_key]?
    persona.api_secret = params[:api_secret] if params[:api_secret]?
    persona.save
    persona
  end
  
  def self.find(id)
    Persona.find_by(id: id, type: "Admin")
  end
  
  def self.find_by(params)
    updated_params = params.to_h
    updated_params[:type] = "Admin"
    Persona.find_by(updated_params)
  end
  
  def self.all
    Persona.where(type: "Admin")
  end
end