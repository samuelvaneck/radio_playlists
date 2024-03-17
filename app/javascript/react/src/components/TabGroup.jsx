import * as React from 'react'
import Tab from './Tab'
import { useState } from "react";

function TabGroup(props) {
    const tabs = props.tabs
    const [selectedTab, setSelectedTab] = useState(0)

    const handleTabClick = (event, tabIndex) => {
        const tabContents = document.querySelectorAll('.tab-content');
        const tabName = tabs[tabIndex][0].toLowerCase()
        const searchPath = tabs[tabIndex][1]
        const button = event.target
        const tabId = button.getAttribute('data-tab');
        const tabContent = document.getElementById(tabId);

        setSelectedTab(tabIndex)
        tabContents.forEach(tabContent => {
            tabContent.classList.add('hidden')
            tabContent.parentNode.classList.remove('active-tab-content-wrapper')
        })

        tabContent.classList.remove('hidden');
        tabContent.parentNode.classList.add('active-tab-content-wrapper');

        const url = new URL(searchPath)
        fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
            .then(response => response.text())
            .then(html => Turbo.renderStreamMessage(html))
    }

    return (
        <div
            className="text-sm font-medium text-center text-gray-500 border-b border-gray-200 dark:text-gray-400 dark:border-gray-700">
            <ul className="flex -mb-px">
                {tabs.map((tab, index) => {
                    return <Tab key={tab}
                                name={tab[0]}
                                searchPath={tab[1]}
                                tabIndex={index}
                                activeTab={selectedTab}
                                dataTabAttribute={tab[2]}
                                onTabClick={handleTabClick} />
                })}
            </ul>
        </div>
    )
}

export default TabGroup
