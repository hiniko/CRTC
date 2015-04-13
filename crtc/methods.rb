class CRTC::Client

    def show(id)
      resp = @server["ticket/#{id}/show"].get
      return process_response(resp) 
    end

    def links(id)
     resp = @server["ticket/#{id}/links/show"].get
     return process_response(resp) 
    end
    
    def attachments(id)
     resp = @server["ticket/#{id}/attachments"].get
#     resp.gsub!(/Attachments:/, '')
#     resp.gsub!(',','')
     return process_response(resp) 
    end

    # RT (4 at any rate) does not require the ticket id to relate to the
    # attachment you are attempting to reterive, making the ticekt ID a useless 
    # parameter. Hopefully they don't change it because I am setting it to 1 to
    # avoid the implicit requirement of a matching ticket id in the def
    # (I would hope they would make major changes like that in thier next
    # iteration of the API. Assumptions!)
    def attachment(aid)
     resp = @server["ticket/1/attachments/#{aid}/"].get
     return process_response(resp, 's', true) 
    end

    def history(id, type='s')
      resp = @server["ticket/#{id}/history?format=#{type[0]}"].get
      return process_response(resp, 'l') if type == 'l'
      return process_response(resp, 's') 
    end
    
    def history_item(id, hid)
      resp = @server["ticket/#{id}/history/id/#{hid}"].get
      return process_response(resp) 
    end
    
    def query(query, format='s', order='LastUpdated')
      format = format[0] if format != 's'
      url = "search/ticket?query=#{query}&orderby=#{order}&format=#{format}"
      resp = @server[URI::encode(url)].get

      return process_response(resp) if format == 's'
      return process_response(resp, 'l')
    end

#
# This method is crazy. It tries to avoid the http plain text REST interface
# and use email to communicate with the RT instance instead. There are a
# number of terrible problems with this idea. Lets never talk about them.
# TODO:: remove / fix 
#
#    def create(text, meta, attachments)
#
#        meta_string = meta.map { |k,v| "#{k}: #{v}" }.join("\n")
#        message = Mail.new
#        message.body = text
#        message.subject = meta[:subject]
#        message.to = "#{meta[:queue]}@#{@server_url}"
#        message.from = "#{@user}@#{@server_url}"
#        attachments.each do |a|
#            message.add_file(a); 
#        end
#        meta.each do |k,v|
#            message.header["X-RT-#{k.to_s.capitalize}"] = v
#        end
#        #puts message.deliver
#    end
end
