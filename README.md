# BitCrusher: An Affordable, Open Source, Electromagnetic Fault Injection Platform
_NOTE: This repository is still under construction, and may be difficult to navigate in its current state_

Security researchers need attainable, effective tooling to secure computing infrastructure against physical attacks. Tools for hardware security research have been
getting cheaper and more effective over recent years, but EMFI tooling has been left behind. The cost of commercial EMFI tooling is typically on the order of tens to hundreds of thousands of dollars, and the highly-coupled proprietary equipment offers little insight to researchers developing or characterizing EMFI techniques. BitCrusher is being developed with the goal of addressing several challenges in this space:

- Supporting the continued improvement of open EMFI platform design techniques by contributing to the thread of research on the design of EMFI equipment
- Supporting the improvement of practical EMFI techniques and countermeasures through attainable and open domain specific instrumentation
- Lowering the high barrier to entry of replicating and expanding upon existing EMFI research by providing high performance equipment that is both affordable and easy to integrate with common existing hardware security instrumentation frameworks (e.g. ChipWhisperer)

## State of BitCrusher
BitCrusher was started as an undergraduate senior project in September 2025. Beginning April 2026, development efforts have been focused on working out design flaws and thoroughly verifying device performance. 


## Licensing
Following the licensing guidelines of [OSHWA](https://oshwa.org/), the components of BitCrusher fall under a combination of OSI-approved licenses. The following licenses were selected with the goals of maximizing this work's benefit to the open hardware and open security research communities and ensuring potential commercial utilization of this work similarly benefits those communities.  

**Firmware and Software:** BitCrusher firmware and software fall under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html) (AGPL-3.0). This includes the BitCrusher device firmware (`/firmware`) and the host-side python interface (`/interface`).  

**Hardware design:** The design materials of BitCrusher (including but not limited to materials in `/design`, excluding those covered under the firmware / software licensing scheme) are licensed under the [CERN Open Hardware Licence Version 2 – Strongly Reciprocal](https://gitlab.com/ohwr/project/cernohl/-/wikis/uploads/819d71bea3458f71fba6cf4fb0f2de6b/cern_ohl_s_v2.txt) (CERN-OHL-S-2.0). 

**Documentation:** Current BitCrusher documentation, including but not limited to user guides / instructions, written documentation of the design, and written engineering work / documentation is under the [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/) license (CC BY-SA 4.0). In cases where documentation is accompanied by code, such as simulations and calculations in `/design-resources`, the code falls under the AGPL-3.0 license while the written work falls under the CC BY-SA 4.0 license. 

While there is currently no sound structure for project governance, the policy for potential future contributions to the project's documentation is that the contributions should be CC BY-SA 4.0 licensed under the title "BitCrusher" and attributed to the respective contributor(s).  

**Branding:** Since this work was named after the [digital audio effect](https://en.wikipedia.org/wiki/Bitcrusher), as well as the fact that this project is a non-commercial endeavor, no restrictions apply to the use of the name BitCrusher. 