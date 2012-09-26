
require 'nokogiri'
require 'open-uri'

BASE_URL = "https://sigarra.up.pt/feup/"
INDEX_URL = "https://sigarra.up.pt/feup/ESTAGIOS_ALUNOS.LISTA_EMPRESAS?p_aluno=080509065&p_processo=1103"
PROFESSOR_URL = BASE_URL + "estagios_alunos.lista_propostas?p_aluno=080509065&p_processo=1103&p_doc_codigo="
COMPANY_URL = BASE_URL + "estagios_alunos.lista_propostas?p_aluno=080509065&p_processo=1103&p_inst_codigo="

DISSERTATION_URL = BASE_URL + "estagios_empresas.ver_dados_proposta?p_id="

COOKIE = "GPAG_CCORRENTE_GERAL_CONTA_CORRENTE_VIEW=0; __utma=130543245.768358309.1337265203.1337265203.1337265203.1; __utmz=130543245.1337265203.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); _pk_ref.5.7cdc=%5B%22%22%2C%22%22%2C1338834354%2C%22http%3A%2F%2Fupin.up.pt%2F%22%5D; _pk_id.5.7cdc=b0c5b8abeea6c398.1337209994.2.1338834354.1337210096.; _pk_ref.23.7cdc=%5B%22%22%2C%22%22%2C1338834354%2C%22http%3A%2F%2Fupin.up.pt%2F%22%5D; _pk_id.23.7cdc=b0c5b8abeea6c398.1337209994.2.1338834354.1337210096.; __atuvc=3|20,0|21,0|22,1|23; FEUPSI_SESSION=20978045; FEUPSI_SECURITY=3B0UhPEVq7DRSF5; FEUPHTTP_SESSION=458134859"

PROFESSORS_REGEX = "p_doc_codigo"
COMPANIES_REGEX = "p_inst_codigo"
THESIS_REGEX = "estagios_empresas"

def get_ids_in_link_by_href_regex(doc, link_regex)
	ids = []
	doc.xpath('//a[@href]').each do |link|
		if link['href'] =~ /#{link_regex}/
			ids << link['href'].split("=").last
		end
	end
	ids
end

def get_html(url)
	Nokogiri::HTML(open(url, "Cookie" => COOKIE))
end

def get_thesis_html_pages()
	dissertation_ids = []
	dissertation_pages = []
	index_page = get_html(INDEX_URL)
	professors_ids = get_ids_in_link_by_href_regex(index_page, PROFESSORS_REGEX)
	companies_ids = get_ids_in_link_by_href_regex(index_page, COMPANIES_REGEX)

	professors_ids.each do |p_id|
		proposed_dissertation_page = get_html(PROFESSOR_URL+p_id)
		dissertation_ids += get_ids_in_link_by_href_regex(proposed_dissertation_page, THESIS_REGEX)
	end
	companies_ids.each do |p_id|
		proposed_dissertation_page = get_html(COMPANY_URL+p_id)
		dissertation_ids += get_ids_in_link_by_href_regex(proposed_dissertation_page, THESIS_REGEX)
	end
	dissertation_ids.each do |thesis|
		dissertation_pages << get_html(DISSERTATION_URL+thesis)
	end
	dissertation_pages
end

PROF_REGEX = "funcionarios_geral"

def dissertation_page_to_hash(dissertation_page)
	dissertation = Hash.new
	dissertation_page.xpath('//a[@href]').each do |link|
		if link['href'] =~ /#{PROF_REGEX}/
			dissertation["Orientador"] = link.text
		end
	end
	dissertation
end


dissertation_pages = get_thesis_html_pages()
dissertation = dissertation_page_to_hash(dissertation_pages.first)
puts dissertation
