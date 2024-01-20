autorun: help

help:
	$(info $()  build ....... generate the static website)
	$(info $()  preview ..... start a static web server to preview the website)
	$(info $()  run ......... run the development server)
	$(info $()  unrelease ... revert the docs directory)
	$(info $()  uplift ...... upgrade Astro and Starlight)

build release:
	astro build && touch docs/.nojekyll

preview:
	npm run preview

run:
	npm run dev

unrelease revert reset :
	git checkout -- docs && git clean -fd -- docs

uplift:
	echo Upgrading Astro and Starlight...
	npx --yes @astrojs/upgrade
