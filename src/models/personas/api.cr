# Api is a factory/helper for creating Api type Personas
class Api
  def self.new
    persona = Persona.new
    persona.type = "Api"
    persona
  end
  
  def self.create(params)
    persona = Persona.new
    persona.type = "Api"
    persona.email = params[:email] if params[:email]?
    persona.password = params[:password] if params[:password]?
    persona.password_confirmation = params[:password_confirmation] if params[:password_confirmation]?
    persona.api_key = params[:api_key] if params[:api_key]?
    persona.api_secret = params[:api_secret] if params[:api_secret]?
    persona.save
    persona
  end
  
  def self.find(id)
    Persona.find_by(id: id, type: "Api")
  end
  
  def self.find_by(params)
    updated_params = params.to_h
    updated_params[:type] = "Api"
    Persona.find_by(updated_params)
  end
  
  def self.all
    Persona.where(type: "Api")
  end
end