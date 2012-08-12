/+
 + imgur.d
 + 
 + Copyright (c) 2012, SARI Eyyüb(eyyub.pangearaion@gmail.com). All rights reserved.
 +
 + This library is free software; you can redistribute it and/or
 + modify it under the terms of the GNU Lesser General Public
 + License as published by the Free Software Foundation; either
 + version 2.1 of the License, or (at your option) any later version.
 +
 + This library is distributed in the hope that it will be useful,
 + but WITHOUT ANY WARRANTY; without even the implied warranty of
 + MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 + Lesser General Public License for more details.
 +
 + You should have received a copy of the GNU Lesser General Public
 + License along with this library; if not, write to the Free Software
 + Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 + MA 02110-1301  USA
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/
module imgur;

import std.stdio : writeln, writefln, File;
import std.conv : to;
import std.net.curl;
import std.base64;
import std.uri : encodeComponent;
import std.array : join;
import std.xml;
import std.string;
import std.regex;
import std.file;


//thanks to dav1d(https://github.com/Dav1dde/BraLa/blob/master/brala/network/util.d#L117)
string urlencode(string[string] values)
{
    string[] parameters;
    
    foreach(key, value; values) 
	{
        parameters ~= key ~ "=" ~ encodeComponent(value);
    }
    
    return parameters.join("&");
}

struct Upload
{
	private
	{
		struct Image
		{
			string name;
			string title;
			string caption;
			string hash;
			string deletehash;
			string datetime;
			string type;
			string animated;
			string width;
			string height;
			string size;
			string views;
			string bandwidth;
		}

		struct Links
		{
			string original;
			string imgur_page;
			string delete_page;
			string small_square;
			string large_thumbnail;
		}
	}
	
	Image image;
	Links links;
}

struct Album
{
	private
	{
		struct Item
		{
			private
			{
				struct Image
				{
					string title;
					string caption;
					string hash;
					string datetime;
					string type;
					string animated;
					string width;
					string height;
					string size;
					string views;
					string bandwidth;
				}
				struct Links
				{
					string original;
					string imgur_page;
					string small_square;
					string large_thumbnail;
				}
			}
			Image image;
			Links links;
		}
	}
	
	string title;
	string description;
	string cover;
	string layout;
	Item[] images;
}

struct Gallery
{
	private
	{
		struct ImageGallery
		{
			string hash;
			string title;
			string score;
			string size;
			string views;
			string datetime;
			string mimetype;
			string ext;
			string width;
			string height;
			string ups;
			string downs;
			string points;
			string reddit;
			string firstpost_date;
			string bandwidth;
			string source;
			string gallery_timestamp;
			string vote;
		}
	}
	
	ImageGallery[] images;
}

struct Delete
{
	string message;
}

struct Stats
{
	private
	{
		struct MostPopularImages
		{
			string[] images_hash;
		}
	}
	MostPopularImages most_popular_images;
	string images_uploaded;
	string images_veiwed;
	string bandwidth_used;
	string average_image_size;
}

struct Oembed
{
	string version_;
	string provider_name;
	string provider_url;
	string url;
	string title;
	string width;
	string hieght;
	string type;
}

// require OAuth 1.0a
/+struct Account
{
	string url;
	string is_pro;
	string default_album_privacy;
	string public_images;
}+/

@property bool isURL(string url)
{
	auto reg = regex(r"([A-Za-z]{3,9})://([-;:&=\+\$,\w]+@{1})?([-A-Za-z0-9\.]+)+:?(\d+)?((/[-\+~%/\.\w]+)?\??([-\+=&;%@\.\w]+)?#?([\w]+)?)?");
	auto result = match(url, reg);
	
	return !result.empty;
}

final class Imgur
{
	private
	{
		string API_KEY;
	}

	public
	{
		this(string APIKEY)
		{
			API_KEY = APIKEY;
		}
		Upload upload(string filename, string type = "", string name = "", string title = "", string caption = "")
		{
			string picture;
			if(filename.isFile)
			{
				auto source = File(filename, "rb");
				scope(exit) source.close();
				ubyte[] data = new ubyte[](source.size);			
				
				picture = to!(string)(Base64.encode(source.rawRead(data)));
			}
			else if(filename.isURL)
				picture = filename;

			string[string] values = ["key" : API_KEY, "image" : picture, "type" : type, "name" : name, "title" : title, "caption" : caption];
			auto content = to!string(post("http://api.imgur.com/2/upload.xml", urlencode(values)));
			
			check(content);
			
			Upload response;
			
			auto imgurXML = new DocumentParser(content);


			imgurXML.onStartTag["image"] = (ElementParser xml)
			{
				xml.onEndTag["name"]       = (in Element e) { response.image.name       = e.text(); };
				xml.onEndTag["title"]      = (in Element e) { response.image.title      = e.text(); };
				xml.onEndTag["caption"]    = (in Element e) { response.image.caption    = e.text(); };
				xml.onEndTag["hash"]       = (in Element e) { response.image.hash       = e.text(); };
				xml.onEndTag["deletehash"] = (in Element e) { response.image.deletehash = e.text(); };
				xml.onEndTag["datetime"]   = (in Element e) { response.image.datetime   = e.text(); };
				xml.onEndTag["type"]       = (in Element e) { response.image.type       = e.text(); };
				xml.onEndTag["animated"]   = (in Element e) { response.image.animated   = e.text(); };
				xml.onEndTag["width"]      = (in Element e) { response.image.width      = e.text(); };
				xml.onEndTag["height"]     = (in Element e) { response.image.height     = e.text(); };
				xml.onEndTag["size"]       = (in Element e) { response.image.size       = e.text(); };
				xml.onEndTag["views"]      = (in Element e) { response.image.views      = e.text(); };
				xml.onEndTag["bandwidth"]  = (in Element e) { response.image.bandwidth  = e.text(); };

				xml.parse();
			};
			
			imgurXML.onStartTag["links"] = (ElementParser xml)
			{
				xml.onEndTag["original"]          = (in Element e) { response.links.original        = e.text(); };
				xml.onEndTag["imgur_page"]        = (in Element e) { response.links.imgur_page      = e.text(); };
				xml.onEndTag["delete_page"]       = (in Element e) { response.links.delete_page     = e.text(); };
				xml.onEndTag["small_square"]      = (in Element e) { response.links.small_square    = e.text(); };
				xml.onEndTag["large_thumbnail"]   = (in Element e) { response.links.large_thumbnail = e.text(); };
				
				xml.parse();
			};
			
			imgurXML.parse();
			
			return response;
		}
		Delete del(string dhash)
		{
			auto content = to!string(get("http://imgur.com/api/delete/%s".xformat(dhash)));
			
			check(content);
			
			Delete response;
			
			auto imgurXML = new DocumentParser(content);
			
			imgurXML.onStartTag["delete"] = (ElementParser xml)
			{
				xml.onEndTag["message"] = (in Element e) { response.message = e.text(); };
				xml.parse();
			};
			imgurXML.parse();
				
			return response;
		}
		Stats stats(string view = "month")
		{
			string[string] values = ["view" : view];
			
			auto content = to!string(get(r"http://api.imgur.com/2/stats?" ~ urlencode(values)));
			
			check(content);
			
			Stats response;
			
			auto imgurXML = new DocumentParser(content);
			
			imgurXML.onStartTag["most_popular_images"] = (ElementParser xml)
			{
				xml.onEndTag["image_hash"] = (in Element e) { response.most_popular_images.images_hash ~= e.text(); };
				xml.parse();
			};
			imgurXML.onEndTag["images_uploaded"]    = (in Element e) { response.images_uploaded    = e.text(); };
			imgurXML.onEndTag["images_veiwed"]      = (in Element e) { response.images_veiwed      = e.text(); };
			imgurXML.onEndTag["bandwidth_used"]     = (in Element e) { response.bandwidth_used     = e.text(); };
			imgurXML.onEndTag["average_image_size"] = (in Element e) { response.average_image_size = e.text(); };
			
			imgurXML.parse();
			
			return response; 	
		}
		Oembed oembed(string url, string format = "", string maxheight = "", string maxwidth = "")
		{
			string[string] values = ["url" : url, "format" : format, "maxheight" : maxheight, "maxwidth" : maxwidth];
			
			auto content = to!string(get(r"http://api.imgur.com/oembed?" ~ urlencode(values)));
			
			check(content);
			
			Oembed response;
			
			auto imgurXML = new DocumentParser(content);
			
			imgurXML.onEndTag["version"]       = (in Element e) { response.version_      = e.text(); };
			imgurXML.onEndTag["provider_name"] = (in Element e) { response.provider_name = e.text(); };
			imgurXML.onEndTag["provider_url"]  = (in Element e) { response.provider_url  = e.text(); };
			imgurXML.onEndTag["url"]           = (in Element e) { response.url           = e.text(); };
			imgurXML.onEndTag["title"]         = (in Element e) { response.title         = e.text(); };
			imgurXML.onEndTag["width"]         = (in Element e) { response.width         = e.text(); };
			imgurXML.onEndTag["hieght"]        = (in Element e) { response.hieght        = e.text(); };
			imgurXML.onEndTag["type"]          = (in Element e) { response.type          = e.text(); };
			
			imgurXML.parse(); 
			
			return response;
		}
		Album album(string id)
		{
			auto content = to!string(get(r"http://api.imgur.com/2/album/" ~ id));
			
			check(content);
			writeln(content);
			Album response;
			
			auto imgurXML = new DocumentParser(content);
			

			imgurXML.onEndTag["title"]       = (in Element e) { response.title       = e.text(); };
			imgurXML.onEndTag["description"] = (in Element e) { response.description = e.text(); };
			imgurXML.onEndTag["cover"]       = (in Element e) { response.cover       = e.text(); };
			imgurXML.onEndTag["layout"]      = (in Element e) { response.layout      = e.text(); };
			imgurXML.onStartTag["images"] = (ElementParser xml2)
			{
				xml2.onStartTag["item"] = (ElementParser xml3)
				{
					Album.Item item;
					xml3.onStartTag["image"] = (ElementParser xml4)
					{
						
						xml4.onEndTag["title"]     = (in Element e) { item.image.title     = e.text(); };
						xml4.onEndTag["caption"]   = (in Element e) { item.image.caption   = e.text(); };
						xml4.onEndTag["hash"]      = (in Element e) { item.image.hash      = e.text(); };
						xml4.onEndTag["datetime"]  = (in Element e) { item.image.datetime  = e.text(); };
						xml4.onEndTag["type"]      = (in Element e) { item.image.type      = e.text(); };
						xml4.onEndTag["animated"]  = (in Element e) { item.image.animated  = e.text(); };
						xml4.onEndTag["width"]     = (in Element e) { item.image.width     = e.text(); };
						xml4.onEndTag["height"]    = (in Element e) { item.image.height    = e.text(); };
						xml4.onEndTag["size"]      = (in Element e) { item.image.size      = e.text(); };
						xml4.onEndTag["views"]     = (in Element e) { item.image.views     = e.text(); };
						xml4.onEndTag["bandwidth"] = (in Element e) { item.image.bandwidth = e.text(); };
						
						xml4.parse();
					};
					xml3.onStartTag["links"] = (ElementParser xml4)
					{
						xml4.onEndTag["original"]        = (in Element e) { item.links.original        = e.text(); };
						xml4.onEndTag["imgur_page"]      = (in Element e) { item.links.imgur_page      = e.text(); };
						xml4.onEndTag["small_square"]    = (in Element e) { item.links.small_square    = e.text(); };
						xml4.onEndTag["large_thumbnail"] = (in Element e) { item.links.large_thumbnail = e.text(); };
						
						xml4.parse();
					};
					
					xml3.parse();
					response.images ~= item;
				};
				
				xml2.parse();
			};

			imgurXML.parse();
			
			return response;
		}
		Gallery gallery(string url = "http://imgur.com/gallery.xml")
		{
			auto content = to!string(get(url));
			
			check(content);
			Gallery response;	
			auto imgurXML = new DocumentParser(content);
			
			imgurXML.onStartTag["item"] = (ElementParser xml)
			{
				Gallery.ImageGallery item;
				xml.onEndTag["hash"]              = (in Element e) { item.hash           = e.text(); };
				xml.onEndTag["title"]             = (in Element e) { item.title          = e.text(); };
				xml.onEndTag["score"]             = (in Element e) { item.score          = e.text(); };
				xml.onEndTag["size"]              = (in Element e) { item.size           = e.text(); };
				xml.onEndTag["views"]             = (in Element e) { item.views          = e.text(); };
				xml.onEndTag["datetime"]          = (in Element e) { item.datetime       = e.text(); };
				xml.onEndTag["mimetype"]          = (in Element e) { item.mimetype       = e.text(); };
				xml.onEndTag["ext"]               = (in Element e) { item.ext            = e.text(); };
				xml.onEndTag["width"]             = (in Element e) { item.width          = e.text(); };
				xml.onEndTag["height"]            = (in Element e) { item.height         = e.text(); };
				xml.onEndTag["ups"]               = (in Element e) { item.ups            = e.text(); };
				xml.onEndTag["downs"]             = (in Element e) { item.downs          = e.text(); };
				xml.onEndTag["points"]            = (in Element e) { item.points         = e.text(); };
				xml.onEndTag["reddit"]            = (in Element e) { item.reddit         = e.text(); };
				xml.onEndTag["firstpost_date"]    = (in Element e) { item.firstpost_date = e.text(); };
				xml.onEndTag["bandwidth"]         = (in Element e) { item.bandwidth      = e.text(); };
				xml.onEndTag["source"]            = (in Element e) { item.source         = e.text(); };
				xml.onEndTag["gallery_timestamp"] = (in Element e) { item.source         = e.text(); };
				xml.onEndTag["vote"]              = (in Element e) { item.vote           = e.text(); };
				
				xml.parse();
				
				response.images ~= item;
			};
			
			imgurXML.parse();
			
			return response;
		}		
	}
}

unittest
{
	auto imgur = new Imgur(YOUR_API_KEY);
	
	auto stats = imgur.stats("today");
	//...
}
